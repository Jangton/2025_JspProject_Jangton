<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.util.Vector" %>
<%@ page import="jspproject.JourBean" %>
<jsp:useBean id="jmgr" class="jspproject.JourMgr"/>
<%
  String user_id = (String) session.getAttribute("user_id");
  if (user_id == null) {
    response.sendRedirect("login.jsp");
    return;
  }
  Vector<JourBean> entries = jmgr.listJour(user_id);
%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <link href="css/diary.css" rel="stylesheet" type="text/css">
</head>
<body>
  <div class="container">
    <!-- 좌측 사이드바 -->
    <div class="sidebar">
      <div class="top-section">
        <form action="jourAdd" method="post">
          <input type="hidden" name="user_id" value="<%= user_id %>" />
          <button type="button" class="button" id="autoAddBtn">+ 일지 추가</button>
        </form>

        <div style="margin-top: 4px; margin-bottom: 6px;">
          <div class="select-all-container">
            <input type="checkbox" id="select-all">
            <label for="select-all">전체 선택</label>
          </div>
        </div>

        <div class="diary-list">
          <% if (entries.size() == 0) { %>
            <div class="placeholder">일지를 추가해보세요</div>
          <% } else {
              for (JourBean bean : entries) {
          %>
            <div class="entry" 
              data-id="<%= bean.getJour_id() %>" 
              data-title="<%= bean.getJour_title().replace("\"", "&quot;") %>" 
              data-content="<%= bean.getJour_cnt().replace("\"", "&quot;").replaceAll("\n", "\\\\n") %>" 
              data-date="<%= bean.getJour_regdate() %>">
              <input type="checkbox">
              <span class="title"><%= bean.getJour_title() %></span>
              <span class="date"><%= bean.getJour_regdate() %></span>
            </div>
          <% } } %>
        </div>
      </div>

      <form id="deleteForm" action="jourDelete" method="post">
        <div id="deleteInputs"></div>
        <button type="submit" class="delete-button">삭제</button>
      </form>
    </div>

    <!-- 우측 상세 보기 -->
    <div class="content" id="contentPanel">
      <form id="updateForm" action="jourUpdate" method="post">
        <input type="hidden" name="jour_id" id="jour_id" />
        <div class="header">
          <input type="text" name="jour_title" id="jour_title" class="title-input1" placeholder="제목" required disabled />
          <div class="diary-icon-container">
            <img src="<%= request.getContextPath() %>/jspproject/icon/아이콘_수정_1.png" class="diary-icon" id="editDiaryIcon">
            <img src="<%= request.getContextPath() %>/jspproject/icon/아이콘_삭제_1.png" class="diary-icon" id="hideContentIcon">
          </div>
        </div>
        <textarea name="jour_cnt" id="jour_cnt" class="input-field" placeholder="내용을 입력하세요..." required disabled></textarea>
        <button type="submit" class="edit-btn" id="updateBtn" style="display:none;">완료</button>
      </form>
    </div>
  </div>

  <script>
    document.addEventListener('DOMContentLoaded', () => {
      const entries = document.querySelectorAll('.entry');
      const titleInput = document.getElementById('jour_title');
      const contentInput = document.getElementById('jour_cnt');
      const idInput = document.getElementById('jour_id');
      const updateBtn = document.getElementById('updateBtn');
      const contentPanel = document.getElementById('contentPanel');

      entries.forEach(entry => {
        entry.addEventListener('click', () => {
          entries.forEach(e => e.classList.remove('active'));
          entry.classList.add('active');

          titleInput.value = entry.dataset.title;
          contentInput.value = entry.dataset.content.replace(/\\n/g, "\n");
          idInput.value = entry.dataset.id;

          // 선택 시 읽기 전용 상태로 초기화
          titleInput.disabled = true;
          contentInput.disabled = true;
          updateBtn.style.display = "none";

          contentPanel.style.display = "flex";
        });
      });

      document.getElementById('select-all').addEventListener('change', function () {
        const checkboxes = document.querySelectorAll('.entry input[type="checkbox"]');
        checkboxes.forEach(cb => cb.checked = this.checked);
      });

      document.getElementById('hideContentIcon').addEventListener('click', async () => {
        const jourId = document.getElementById('jour_id').value;

        if (!jourId) {
          alert("삭제할 일지를 먼저 선택하세요.");
          return;
        }

        if (!confirm("이 일지를 삭제하시겠습니까?")) return;

        const params = new URLSearchParams();
        params.append("rnum", jourId);

        const response = await fetch("jourDelete", {
          method: "POST",
          headers: {
            "Content-Type": "application/x-www-form-urlencoded"
          },
          body: params.toString()
        });

        if (response.ok) {
          location.href = "mainScreen.jsp";
        }
      });

      let isEditing = false;

      document.getElementById('editDiaryIcon').addEventListener('click', () => {
        if (!isEditing) {
          titleInput.disabled = false;
          contentInput.disabled = false;
          updateBtn.style.display = "block";
          isEditing = true;
        } else {
          titleInput.disabled = true;
          contentInput.disabled = true;
          updateBtn.style.display = "none";
          isEditing = false;
        }
      });

      const userId = "<%= user_id.replaceAll("\"", "\\\"") %>";

      document.getElementById("autoAddBtn").addEventListener("click", async () => {
    	  const params = new URLSearchParams();
    	  params.append("user_id", userId);
    	  params.append("jour_title", "새 일지");
    	  params.append("jour_cnt", "내용을 입력하세요...");

    	  const response = await fetch("jourAdd", {
    	    method: "POST",
    	    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    	    body: params.toString()
    	  });

    	  if (response.ok) {
    	    const data = await response.json();

    	    // ✅ placeholder 제거
    	    const placeholder = document.querySelector(".diary-list .placeholder");
    	    if (placeholder) placeholder.remove();

    	    const newEntry = createEntryElement(data.jour_id, "새 일지", "내용을 입력하세요...", data.jour_regdate);
    	    document.querySelector(".diary-list").prepend(newEntry);
    	    attachEntryClick(newEntry);
    	    newEntry.click();
    	  } else {
    	    alert("일지 추가 실패");
    	  }
    	});


      function createEntryElement(id, title, content, regdate) {
        const div = document.createElement("div");
        div.className = "entry";
        div.dataset.id = id;
        div.dataset.title = title;
        div.dataset.content = content.replace(/\n/g, "\\n");
        div.dataset.date = regdate;

        const checkbox = document.createElement("input");
        checkbox.type = "checkbox";

        const titleSpan = document.createElement("span");
        titleSpan.className = "title";
        titleSpan.textContent = title;

        const dateSpan = document.createElement("span");
        dateSpan.className = "date";
        dateSpan.textContent = regdate;

        div.appendChild(checkbox);
        div.appendChild(titleSpan);
        div.appendChild(dateSpan);

        return div;
      }

      function attachEntryClick(entry) {
        entry.addEventListener("click", () => {
          document.querySelectorAll(".entry").forEach(e => e.classList.remove("active"));
          entry.classList.add("active");

          titleInput.value = entry.dataset.title;
          contentInput.value = entry.dataset.content.replace(/\\n/g, "\n");
          idInput.value = entry.dataset.id;

          titleInput.disabled = true;
          contentInput.disabled = true;
          updateBtn.style.display = "none";
          isEditing = false;

          contentPanel.style.display = "flex";
        });
      }

      document.getElementById('deleteForm').addEventListener('submit', function (e) {
    	  const deleteInputs = document.getElementById('deleteInputs');
    	  deleteInputs.innerHTML = '';

    	  const checkedEntries = document.querySelectorAll('.entry input[type="checkbox"]:checked');

    	  if (checkedEntries.length === 0) {
    	    e.preventDefault();
    	    alert("삭제할 항목을 선택하세요.");
    	    return;
    	  }

    	  // ✅ 삭제 전 사용자 확인
    	  if (checkedEntries.length === 1) {
    	    if (!confirm("일지를 삭제하시겠습니까?")) {
    	      e.preventDefault();
    	      return;
    	    }
    	  } else {
    	    if (!confirm("일지를 전체 삭제하시겠습니까?")) {
    	      e.preventDefault();
    	      return;
    	    }
    	  }

    	  // ✅ 삭제할 항목들을 hidden input으로 추가
    	  checkedEntries.forEach(entryCheckbox => {
    	    const entryDiv = entryCheckbox.closest('.entry');
    	    const jourId = entryDiv.dataset.id;

    	    const input = document.createElement('input');
    	    input.type = 'hidden';
    	    input.name = 'rnum';
    	    input.value = jourId;

    	    deleteInputs.appendChild(input);
    	  });
    	});
    });
  </script>
</body>
</html>
